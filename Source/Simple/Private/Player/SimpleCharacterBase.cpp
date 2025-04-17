// Fill out your copyright notice in the Description page of Project Settings.

#include "Player/SimpleCharacterBase.h"
#include "Abilities/SimpleAbilitySystemComponent.h"
#include "Player/SimplePlayerState.h"
#include "Player/SimplePlayerController.h"
#include "Player/SimpleEnhancedInputComponent.h"
#include "EnhancedInputSubsystems.h"
#include "System/SimplePawnData.h"
#include "UserSettings/EnhancedInputUserSettings.h"
#include "InputMappingContext.h"
#include "SimpleGameplayTags.h"
#include "Player/SimpleCharacterMovementComponent.h"
#include "Components/SkeletalMeshComponent.h"
#include "Components/CapsuleComponent.h"
#include "Camera/SimpleCameraComponent.h"
#include "Component/SimpleInputComponent.h"


ASimpleCharacterBase::ASimpleCharacterBase(const FObjectInitializer& ObjectInitializer)
	: Super(ObjectInitializer.SetDefaultSubobjectClass<USimpleCharacterMovementComponent>(ACharacter::CharacterMovementComponentName))
{
	PrimaryActorTick.bCanEverTick = false;
	PrimaryActorTick.bStartWithTickEnabled = false;

	SetNetCullDistanceSquared(900000000.0f);

	UCapsuleComponent* CapsuleComp = GetCapsuleComponent();
	CapsuleComp->InitCapsuleSize(40.0f, 90.0f);

	USkeletalMeshComponent* SkeletalMeshComponent = GetMesh();
	SkeletalMeshComponent->SetRelativeRotation(FRotator(0.0f, -90.0f, 0.0f));

	USimpleCharacterMovementComponent* SimpleCharacterMovementComponent = CastChecked<USimpleCharacterMovementComponent>(GetCharacterMovement());
	SimpleCharacterMovementComponent->GravityScale = 1.0f;
	SimpleCharacterMovementComponent->MaxAcceleration = 2400.0f;
	SimpleCharacterMovementComponent->BrakingFrictionFactor = 1.0f;
	SimpleCharacterMovementComponent->BrakingFriction = 6.0f;
	SimpleCharacterMovementComponent->GroundFriction = 8.0f;
	SimpleCharacterMovementComponent->BrakingDecelerationWalking = 1400.0f;
	SimpleCharacterMovementComponent->bUseControllerDesiredRotation = false;
	SimpleCharacterMovementComponent->bOrientRotationToMovement = false;
	SimpleCharacterMovementComponent->RotationRate = FRotator(0.0f, 720.0f, 0.0f);
	SimpleCharacterMovementComponent->bAllowPhysicsRotationDuringAnimRootMotion = false;
	SimpleCharacterMovementComponent->GetNavAgentPropertiesRef().bCanCrouch = true;
	SimpleCharacterMovementComponent->bCanWalkOffLedgesWhenCrouching = true;
	SimpleCharacterMovementComponent->SetCrouchedHalfHeight(65.0f);

	bUseControllerRotationPitch = false;
	bUseControllerRotationYaw = true;
	bUseControllerRotationRoll = false;

	SetReplicates(true);

	AbilitySystemComponent = nullptr;
}


UAbilitySystemComponent* ASimpleCharacterBase::GetAbilitySystemComponent() const
{
	return AbilitySystemComponent;
}


void ASimpleCharacterBase::PossessedBy(AController* NewController)
{
	Super::PossessedBy(NewController);

	ASimplePlayerState* SimplePlayerState = GetPlayerState<ASimplePlayerState>();
	if (SimplePlayerState)
	{
		InitializeAbilitySystem(SimplePlayerState->GetSimpleAbilitySystemComponent(), this);
	}
}


void ASimpleCharacterBase::OnRep_PlayerState()
{
	Super::OnRep_PlayerState();

	ASimplePlayerState* SimplePlayerState = GetPlayerState<ASimplePlayerState>();
	if (SimplePlayerState)
	{
		InitializeAbilitySystem(SimplePlayerState->GetSimpleAbilitySystemComponent(), this);
	}
}

void ASimpleCharacterBase::UninitializeAbilitySystem()
{
	if (!AbilitySystemComponent)
	{
		return;
	}

	if (AbilitySystemComponent->GetAvatarActor() == this)
	{
		AbilitySystemComponent->DestroyActiveState();
		AbilitySystemComponent->RemoveAllGameplayCues();

		if (AbilitySystemComponent->GetOwnerActor() != nullptr)
		{
			AbilitySystemComponent->SetAvatarActor(nullptr);
		}
		else
		{
			AbilitySystemComponent->ClearActorInfo();
		}
	}

	AbilitySystemComponent = nullptr;
}

void ASimpleCharacterBase::InitializeAbilitySystem(USimpleAbilitySystemComponent* InSimpleAbilitySystemComponent, AActor* InOwnerActor)
{
	if (AbilitySystemComponent == InSimpleAbilitySystemComponent)
	{
		return;
	}

	if (AbilitySystemComponent)
	{
		UninitializeAbilitySystem();
	}

	AActor* ExistingAvatar = InSimpleAbilitySystemComponent->GetAvatarActor();

	if ((ExistingAvatar != nullptr) && (ExistingAvatar != this))
	{
		UE_LOG(LogClass, Log, TEXT("Existing avatar (authority=%d)"), ExistingAvatar->HasAuthority() ? 1 : 0);

		ensure(!ExistingAvatar->HasAuthority());

		if (ASimpleCharacterBase* OtherExistingAvatar = Cast<ASimpleCharacterBase>(ExistingAvatar))
		{
			OtherExistingAvatar->UninitializeAbilitySystem();
		}
	}

	AbilitySystemComponent = InSimpleAbilitySystemComponent;
	AbilitySystemComponent->InitAbilityActorInfo(InOwnerActor, this);

	OnInitializedAbilitySystem();
}

void ASimpleCharacterBase::OnInitializedAbilitySystem()
{
	K2_OnInitializedAbilitySystem(AbilitySystemComponent);
}

void ASimpleCharacterBase::OnDeathStarted(AActor* OwningActor)
{
	DisableMovementAndCollision();
}

void ASimpleCharacterBase::OnDeathFinished(AActor* OwningActor)
{
	GetWorld()->GetTimerManager().SetTimerForNextTick(this, &ThisClass::DestroyDueToDeath);
}

void ASimpleCharacterBase::DisableMovementAndCollision()
{
	if (Controller)
	{
		Controller->SetIgnoreMoveInput(true);
	}

	UCapsuleComponent* CapsuleComp = GetCapsuleComponent();
	check(CapsuleComp);
	CapsuleComp->SetCollisionEnabled(ECollisionEnabled::NoCollision);
	CapsuleComp->SetCollisionResponseToAllChannels(ECR_Ignore);

	USimpleCharacterMovementComponent* SimpleCharacterMovementComponent = CastChecked<USimpleCharacterMovementComponent>(GetCharacterMovement());
	SimpleCharacterMovementComponent->StopMovementImmediately();
	SimpleCharacterMovementComponent->DisableMovement();
}

void ASimpleCharacterBase::DestroyDueToDeath()
{
	K2_OnDeathFinished();

	UninitAndDestroy();
}

void ASimpleCharacterBase::UninitAndDestroy()
{
	if (GetLocalRole() == ROLE_Authority)
	{
		DetachFromControllerPendingDestroy();
		SetLifeSpan(0.1f);
	}

	if (USimpleAbilitySystemComponent* SimpleAbilitySystemComponent = GetSimpleAbilitySystemComponent())
	{
		if (SimpleAbilitySystemComponent->GetAvatarActor() == this)
		{
			UninitializeAbilitySystem();
		}
	}

	SetActorHiddenInGame(true);
}
